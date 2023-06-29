#import <Quartz/Quartz.h>
#import <Vision/Vision.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *target = @"test.pdf";
        CGFloat dpi = 200;
        PDFDocument *doc = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:target]];
        NSUInteger pageCount = [doc pageCount];
        
        VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
            NSArray<VNRecognizedTextObservation*> *observations = [request results];
            for (VNRecognizedTextObservation* observation in observations) {
                NSString *string = [[[observation topCandidates:1] firstObject] string];
                puts(string.UTF8String);
            }
        }];
        
        request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
        request.usesLanguageCorrection = YES;
        request.recognitionLanguages = @[@"ja", @"en"];
        
        NSInteger revision;
        if (@available(macOS 13.0, *)) {
            revision = VNRecognizeTextRequestRevision3;
        } else if (@available(macOS 11.0, *)) {
            revision = VNRecognizeTextRequestRevision2;
        } else {
            revision = VNRecognizeTextRequestRevision1;
        }
        request.revision = revision;
        
        for (NSUInteger i=0; i<pageCount; i++) {
            CGFloat scaleFactor = dpi / (72.0 * [[NSScreen mainScreen] backingScaleFactor]);
            NSPDFImageRep *pdfImageRep = [NSPDFImageRep imageRepWithData:[[doc pageAtIndex:i] dataRepresentation]];
            NSSize originalSize = pdfImageRep.bounds.size;
            NSSize scaledSize = NSMakeSize(originalSize.width * scaleFactor, originalSize.height * scaleFactor);
            NSRect targetRect = NSMakeRect(0, 0, scaledSize.width, scaledSize.height);
            NSImage *image = [[NSImage alloc] initWithSize: targetRect.size];
            [image lockFocus];
            [[NSColor whiteColor] set];
            [NSBezierPath fillRect: targetRect];
            [pdfImageRep drawInRect: targetRect];
            [image unlockFocus];
            CGImageRef cgImage = [[NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]] CGImage];
            [[[VNImageRequestHandler alloc] initWithCGImage:cgImage options:@{}] performRequests:@[request] error:nil];
        }
 
        return 0;
    }
}
