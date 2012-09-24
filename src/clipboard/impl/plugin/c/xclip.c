/* includes */
#if defined __USE_POSIX || defined __unix__ || defined _POSIX_C_SOURCE || defined __APPLE__
#elif defined WIN32
#include <Windows.h>
#else
#endif

/* is native? */
int xclip_native(void) {
#if defined __USE_POSIX || defined __unix__ || defined _POSIX_C_SOURCE || defined __APPLE__
     return 0; /* not yet implemented */
#elif defined WIN32
     return 1; /* not yet implemented */
#else
     return 0;
#endif
}

/* the actual clipboard copy */
void xclip_copy(void *string) {
#if defined __USE_POSIX || defined __unix__ || defined _POSIX_C_SOURCE || defined __APPLE__
     /* not yet implemented */
#elif defined WIN32

   LPWSTR  lptstrCopy;
   HGLOBAL hglbCopy;
   std::wstring text;

   text = _winUTF8ToUTF16(string);

   // Open the clipboard, and empty it.

   if (OpenClipboard(NULL)) {
      EmptyClipboard();

      // Allocate a global memory object for the text.
      hglbCopy = GlobalAlloc(GMEM_MOVEABLE, ((text.length() + 1) * sizeof(WCHAR)));

      if (hglbCopy)
      {
         // Lock the handle and copy the text to the buffer.
         lptstrCopy = (LPWSTR)GlobalLock(hglbCopy);
         memcpy(lptstrCopy, text.c_str(), (text.length() + 1) * sizeof(WCHAR) );
         lptstrCopy[(text.length() + 1) * sizeof(WCHAR)] = (WCHAR) 0;    // null character

         // Place the handle on the clipboard.
         SetClipboardData(CF_UNICODETEXT, hglbCopy);

         GlobalUnlock(hglbCopy);
      }

      // Close the clipboard.
      CloseClipboard();
   }

#else
     /* must not happen => ugly crash */
     int*p=0;*p=0;
#endif
}
