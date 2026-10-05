import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../services/database_service.dart';

part '../pro/export/export_service_pro.dart';

class ExportService {
  final DatabaseService _databaseService = DatabaseService();

  // ═════════════════════════════════════════════════════════════════════
  //  FREE FORMATS
  // ═════════════════════════════════════════════════════════════════════

  /// Export a single conversation to TXT format
  Future<File> exportChatToTxt(ChatConversation conversation, List<ChatMessage> messages) async {
    final buffer = StringBuffer();
    
    // Add header
    buffer.writeln('=' * 60);
    buffer.writeln('Chat Export: ${conversation.title}');
    buffer.writeln('Created: ${conversation.createdAt.toString()}');
    buffer.writeln('Updated: ${conversation.updatedAt.toString()}');
    buffer.writeln('=' * 60);
    buffer.writeln();

    // Add messages
    for (final message in messages) {
      // Skip tool messages
      if (message.role == 'tool' || message.content.startsWith('Tool call:')) {
        continue;
      }

      final role = message.role == 'user' ? 'You' : 'Assistant';
      final timestamp = message.timestamp.toString().substring(0, 19);
      
      buffer.writeln('[$timestamp] $role:');
      buffer.writeln(message.content);
      buffer.writeln();
      buffer.writeln('-' * 60);
      buffer.writeln();
    }

    // Write to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${conversation.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.txt';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());

    return file;
  }

  /// Export a single conversation to PDF format with markdown, images, and attachments
  Future<File> exportChatToPdf(ChatConversation conversation, List<ChatMessage> messages) async {
    final PdfDocument document = PdfDocument();
    
    // Define fonts and styles
    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final PdfFont headerFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
    final PdfFont bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final PdfFont boldFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
    final PdfFont codeFont = PdfStandardFont(PdfFontFamily.courier, 9);
    final PdfFont metaFont = PdfStandardFont(PdfFontFamily.helvetica, 8);
    final PdfFont attachmentFont = PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.italic);
    
    double yPosition = 40;
    int currentPageIndex = 0;
    
    PdfPage getCurrentPage() {
      while (document.pages.count <= currentPageIndex) {
        document.pages.add();
      }
      return document.pages[currentPageIndex];
    }
    
    double getPageHeight() => getCurrentPage().getClientSize().height;
    double getPageWidth() => getCurrentPage().getClientSize().width;
    
    const double margin = 40;
    double contentWidth() => getPageWidth() - (margin * 2);

    // Helper to add new page if needed
    void checkPageBreak(double requiredSpace) {
      if (yPosition + requiredSpace > getPageHeight() - 40) {
        currentPageIndex++;
        yPosition = 40;
      }
    }

    // Draw title
    getCurrentPage().graphics.drawString(
      conversation.title,
      titleFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth(), 30),
    );
    yPosition += 40;

    // Draw metadata
    final metaText = 'Created: ${conversation.createdAt.toString().substring(0, 19)} | '
                     'Updated: ${conversation.updatedAt.toString().substring(0, 19)}';
    getCurrentPage().graphics.drawString(
      metaText,
      metaFont,
      bounds: Rect.fromLTWH(margin, yPosition, contentWidth(), 20),
      brush: PdfBrushes.gray,
    );
    yPosition += 25;

    // Draw separator
    getCurrentPage().graphics.drawLine(
      PdfPen(PdfColor(200, 200, 200)),
      Offset(margin, yPosition),
      Offset(getPageWidth() - margin, yPosition),
    );
    yPosition += 20;

    // Process each message
    for (final message in messages) {
      // Skip tool messages
      if (message.role == 'tool' || message.content.startsWith('Tool call:')) {
        continue;
      }

      checkPageBreak(80);

      final role = message.role == 'user' ? 'You' : 'Assistant';
      final timestamp = message.timestamp.toString().substring(0, 19);
      
      // Draw role and timestamp header
      getCurrentPage().graphics.drawString(
        '$role • $timestamp',
        headerFont,
        bounds: Rect.fromLTWH(margin, yPosition, contentWidth(), 20),
        brush: message.role == 'user' ? PdfBrushes.blue : PdfBrushes.green,
      );
      yPosition += 25;

      // Draw attached images (if any)
      if (message.imageUrls != null && message.imageUrls!.isNotEmpty) {
        for (final imageUrl in message.imageUrls!) {
          checkPageBreak(150);
          
          try {
            Uint8List? imageBytes;
            
            // Check if it's a base64 image
            if (imageUrl.startsWith('data:image')) {
              final base64Data = imageUrl.split(',').last;
              imageBytes = base64Decode(base64Data);
            } else if (imageUrl.startsWith('/') || imageUrl.contains('://') == false) {
              // It's a file path
              final imageFile = File(imageUrl);
              if (await imageFile.exists()) {
                imageBytes = await imageFile.readAsBytes();
              }
            }
            
            if (imageBytes != null) {
              final PdfBitmap image = PdfBitmap(imageBytes);
              
              // Scale image to fit within content width while maintaining aspect ratio
              double imgWidth = image.width.toDouble();
              double imgHeight = image.height.toDouble();
              final maxWidth = contentWidth() - 20;
              const maxHeight = 200.0;
              
              if (imgWidth > maxWidth) {
                final ratio = maxWidth / imgWidth;
                imgWidth = maxWidth;
                imgHeight = imgHeight * ratio;
              }
              if (imgHeight > maxHeight) {
                final ratio = maxHeight / imgHeight;
                imgHeight = maxHeight;
                imgWidth = imgWidth * ratio;
              }
              
              checkPageBreak(imgHeight + 10);
              
              getCurrentPage().graphics.drawImage(
                image,
                Rect.fromLTWH(margin + 10, yPosition, imgWidth, imgHeight),
              );
              yPosition += imgHeight + 10;
            }
          } catch (e) {
            // If image loading fails, show placeholder text
            getCurrentPage().graphics.drawString(
              '[Image attachment - unable to load]',
              attachmentFont,
              bounds: Rect.fromLTWH(margin + 10, yPosition, contentWidth() - 10, 20),
              brush: PdfBrushes.gray,
            );
            yPosition += 20;
          }
        }
      }

      // Draw file attachments info (if any)
      if (message.fileAttachments != null && message.fileAttachments!.isNotEmpty) {
        for (final attachment in message.fileAttachments!) {
          checkPageBreak(25);
          
          final attachmentText = '📎 ${attachment.fileName} (${attachment.typeDisplayName})';
          getCurrentPage().graphics.drawString(
            attachmentText,
            attachmentFont,
            bounds: Rect.fromLTWH(margin + 10, yPosition, contentWidth() - 10, 20),
            brush: PdfBrushes.darkGray,
          );
          yPosition += 20;
        }
      }

      // Parse and render markdown content
      final content = message.content;
      final lines = content.split('\n');
      bool inCodeBlock = false;
      String codeBlockContent = '';
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        
        // Handle code blocks
        if (line.trim().startsWith('```')) {
          if (inCodeBlock) {
            // End of code block - render accumulated code
            if (codeBlockContent.isNotEmpty) {
              checkPageBreak(50);
              
              // Draw code block background
              final codeLines = codeBlockContent.split('\n');
              final codeHeight = (codeLines.length * 12.0) + 16;
              
              checkPageBreak(codeHeight);
              
              getCurrentPage().graphics.drawRectangle(
                brush: PdfSolidBrush(PdfColor(245, 245, 245)),
                bounds: Rect.fromLTWH(margin + 10, yPosition, contentWidth() - 20, codeHeight),
              );
              
              getCurrentPage().graphics.drawRectangle(
                pen: PdfPen(PdfColor(220, 220, 220)),
                bounds: Rect.fromLTWH(margin + 10, yPosition, contentWidth() - 20, codeHeight),
              );
              
              // Draw code text
              final textElement = PdfTextElement(
                text: codeBlockContent,
                font: codeFont,
              );
              textElement.draw(
                page: getCurrentPage(),
                bounds: Rect.fromLTWH(margin + 18, yPosition + 8, contentWidth() - 36, 0),
              );
              
              yPosition += codeHeight + 10;
            }
            inCodeBlock = false;
            codeBlockContent = '';
          } else {
            // Start of code block
            inCodeBlock = true;
          }
          continue;
        }
        
        if (inCodeBlock) {
          codeBlockContent += (codeBlockContent.isEmpty ? '' : '\n') + line;
          continue;
        }
        
        // Skip empty lines but add spacing
        if (line.trim().isEmpty) {
          yPosition += 8;
          continue;
        }
        
        checkPageBreak(20);
        
        // Render markdown headers
        if (line.startsWith('### ')) {
          final headerText = line.substring(4);
          getCurrentPage().graphics.drawString(
            headerText,
            boldFont,
            bounds: Rect.fromLTWH(margin + 10, yPosition, contentWidth() - 10, 20),
          );
          yPosition += 18;
        } else if (line.startsWith('## ')) {
          final headerText = line.substring(3);
          getCurrentPage().graphics.drawString(
            headerText,
            PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
            bounds: Rect.fromLTWH(margin + 10, yPosition, contentWidth() - 10, 22),
          );
          yPosition += 22;
        } else if (line.startsWith('# ')) {
          final headerText = line.substring(2);
          getCurrentPage().graphics.drawString(
            headerText,
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
            bounds: Rect.fromLTWH(margin + 10, yPosition, contentWidth() - 10, 24),
          );
          yPosition += 24;
        } else if (line.startsWith('- ') || line.startsWith('* ')) {
          // Bullet list item
          final listText = '• ${line.substring(2)}';
          final textElement = PdfTextElement(text: listText, font: bodyFont);
          final result = textElement.draw(
            page: getCurrentPage(),
            bounds: Rect.fromLTWH(margin + 20, yPosition, contentWidth() - 30, 0),
          );
          yPosition = result!.bounds.bottom + 4;
        } else if (RegExp(r'^\d+\. ').hasMatch(line)) {
          // Numbered list item
          final textElement = PdfTextElement(text: line, font: bodyFont);
          final result = textElement.draw(
            page: getCurrentPage(),
            bounds: Rect.fromLTWH(margin + 20, yPosition, contentWidth() - 30, 0),
          );
          yPosition = result!.bounds.bottom + 4;
        } else {
          // Regular text - handle inline formatting
          // For simplicity, render as plain text (inline bold/italic would require complex parsing)
          final cleanLine = line
              .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'\1')  // Remove bold markers
              .replaceAll(RegExp(r'\*(.+?)\*'), r'\1')       // Remove italic markers
              .replaceAll(RegExp(r'`(.+?)`'), r'\1');        // Remove inline code markers
          
          final textElement = PdfTextElement(text: cleanLine, font: bodyFont);
          final result = textElement.draw(
            page: getCurrentPage(),
            bounds: Rect.fromLTWH(margin + 10, yPosition, contentWidth() - 10, 0),
          );
          yPosition = result!.bounds.bottom + 4;
        }
        
        // Check for page break after each line
        if (yPosition > getPageHeight() - 60) {
          currentPageIndex++;
          yPosition = 40;
        }
      }

      yPosition += 10;
      
      // Draw separator between messages
      checkPageBreak(15);
      getCurrentPage().graphics.drawLine(
        PdfPen(PdfColor(230, 230, 230)),
        Offset(margin, yPosition),
        Offset(getPageWidth() - margin, yPosition),
      );
      yPosition += 15;
    }

    // Save the document
    final List<int> bytes = await document.save();
    document.dispose();

    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${conversation.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);

    return file;
  }

  /// Export all conversations to a ZIP file
  Future<File> exportAllChatsToZip() async {
    final conversations = await _databaseService.getAllConversations();
    final archive = Archive();
    
    // Create a timestamp for the export
    final timestamp = DateTime.now().toString().substring(0, 19).replaceAll(':', '-');

    for (final conversation in conversations) {
      final messages = await _databaseService.getMessagesForConversation(conversation.id);
      
      // Filter out tool messages
      final visibleMessages = messages.where((m) => 
        m.role != 'tool' && !m.content.startsWith('Tool call:')
      ).toList();

      // Create TXT content for this conversation
      final buffer = StringBuffer();
      buffer.writeln('Chat: ${conversation.title}');
      buffer.writeln('Created: ${conversation.createdAt}');
      buffer.writeln('Updated: ${conversation.updatedAt}');
      buffer.writeln('=' * 60);
      buffer.writeln();

      for (final message in visibleMessages) {
        final role = message.role == 'user' ? 'You' : 'Assistant';
        buffer.writeln('[$role - ${message.timestamp}]');
        buffer.writeln(message.content);
        buffer.writeln();
        buffer.writeln('-' * 40);
        buffer.writeln();
      }

      // Add to archive
      final fileName = '${conversation.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}.txt';
      final fileData = buffer.toString();
      archive.addFile(ArchiveFile(fileName, fileData.length, fileData.codeUnits));
    }

    // Create a metadata file
    final metadata = StringBuffer();
    metadata.writeln('LM Mini - Chat Export');
    metadata.writeln('Export Date: $timestamp');
    metadata.writeln('Total Conversations: ${conversations.length}');
    metadata.writeln();
    metadata.writeln('Conversations:');
    for (final conv in conversations) {
      metadata.writeln('- ${conv.title} (${conv.messageIds.length} messages)');
    }
    
    archive.addFile(ArchiveFile('_export_info.txt', metadata.length, metadata.toString().codeUnits));

    // Save ZIP file
    final directory = await getApplicationDocumentsDirectory();
    final zipFileName = 'lm_mini_export_$timestamp.zip';
    final zipFile = File('${directory.path}/$zipFileName');
    
    final encoder = ZipEncoder();
    final outputStream = OutputFileStream(zipFile.path);
    encoder.encode(archive, output: outputStream);
    await outputStream.close();

    return zipFile;
  }

  /// Share a file using the native share dialog
  Future<void> shareFile(File file, String mimeType) async {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: 'Chat Export from LM Mini',
      // Required for iPad - provide a share position origin
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
    );
  }

  /// Export single chat with format selection
  Future<void> exportChat(
    ChatConversation conversation,
    List<ChatMessage> messages,
    String format,
  ) async {
    File exportedFile;
    String mimeType;

    switch (format) {
      case 'pdf':
        exportedFile = await exportChatToPdf(conversation, messages);
        mimeType = 'application/pdf';
      case 'markdown':
        exportedFile = await exportChatToMarkdown(conversation, messages);
        mimeType = 'text/markdown';
      case 'obsidian':
        exportedFile = await exportChatToObsidian(conversation, messages);
        mimeType = 'text/markdown';
      case 'json':
        exportedFile = await exportChatToJson(conversation, messages);
        mimeType = 'application/json';
      default:
        exportedFile = await exportChatToTxt(conversation, messages);
        mimeType = 'text/plain';
    }

    await shareFile(exportedFile, mimeType);
  }

  /// Export all chats as ZIP
  Future<void> exportAllChats() async {
    final zipFile = await exportAllChatsToZip();
    await shareFile(zipFile, 'application/zip');
  }

  // ═════════════════════════════════════════════════════════════════════
  //  PREMIUM FORMATS (implemented in the Pro part; the open-source build
  //  throws UnsupportedError)
  // ═════════════════════════════════════════════════════════════════════

  /// Copy a conversation to clipboard as Markdown.
  Future<void> copyToClipboard(
    ChatConversation conversation,
    List<ChatMessage> messages,
  ) =>
      _proCopyToClipboard(conversation, messages);

  /// Export a conversation to a clean Markdown file.
  Future<File> exportChatToMarkdown(
    ChatConversation conversation,
    List<ChatMessage> messages,
  ) =>
      _proExportMarkdown(conversation, messages);

  /// Export with YAML frontmatter suitable for Obsidian vaults.
  Future<File> exportChatToObsidian(
    ChatConversation conversation,
    List<ChatMessage> messages,
  ) =>
      _proExportObsidian(conversation, messages);

  /// Export conversation with all metadata as structured JSON.
  Future<File> exportChatToJson(
    ChatConversation conversation,
    List<ChatMessage> messages,
  ) =>
      _proExportJson(conversation, messages);
}
