//
//  PDFExportService.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//


import UIKit
import PDFKit

enum PDFExportError: Error, LocalizedError {
    case resumeTooLong
    var errorDescription: String? {
        switch self {
        case .resumeTooLong:
            return "Resumes should not be more than two pages."
        }
    }
}

final class PDFExportService {
    static func export(resume: Resume, fileName: String = "Resume.pdf") throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent(fileName)
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let textRect = CGRect(x: 32, y: 32, width: pageRect.width - 64, height: pageRect.height - 64)
        let maxPages = 2

        let attributedResume = ResumePDFFormatter.attributedString(for: resume, pageWidth: pageRect.width)

        // Use NSLayoutManager to paginate the attributed string
        let textStorage = NSTextStorage(attributedString: attributedResume)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        var pageRanges: [NSRange] = []
        var pageStart = 0

        for _ in 0..<maxPages {
            let textContainer = NSTextContainer(size: textRect.size)
            layoutManager.addTextContainer(textContainer)
            let glyphRange = layoutManager.glyphRange(for: textContainer)
            let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            pageRanges.append(charRange)
            pageStart = charRange.location + charRange.length
            if pageStart >= attributedResume.length { break }
        }

        // If not all text fits in two pages, throw error
        if pageStart < attributedResume.length {
            throw PDFExportError.resumeTooLong
        }

        // Render PDF
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { ctx in
            for range in pageRanges {
                ctx.beginPage()
                let pageText = attributedResume.attributedSubstring(from: range)
                pageText.draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            }
        }
        try data.write(to: url, options: Data.WritingOptions.atomic)
        return url
    }
}
