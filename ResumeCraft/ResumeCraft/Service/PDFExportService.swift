//
//  PDFExportService.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import UIKit
import PDFKit

final class PDFExportService {
    static func export(resume: Resume, fileName: String = "Resume.pdf") throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent(fileName)
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)

        let attributedResume = ResumePDFFormatter.attributedString(for: resume, pageWidth: pageRect.width)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let textRect = CGRect(x: 32, y: 32, width: pageRect.width - 64, height: pageRect.height - 64)
            attributedResume.draw(in: textRect)
        }
        try data.write(to: url, options: .atomic)
        return url
    }
}
