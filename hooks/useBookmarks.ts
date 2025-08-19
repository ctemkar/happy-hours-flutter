import { useState, useEffect, useRef } from 'react';
import { BookmarkService } from '@/lib/bookmarkService';

export function useBookmarks() {
  const [bookmarkedPlaces, setBookmarkedPlaces] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const mountedRef = useRef(true);

  useEffect(() => {
    mountedRef.current = true;
    loadBookmarks();

    return () => {
      mountedRef.current = false;
    };
  }, []);

  const loadBookmarks = async () => {
    try {
      const bookmarks = await BookmarkService.getBookmarkedPlaces();
      if (mountedRef.current) {
        setBookmarkedPlaces(bookmarks);
      }
    } catch (error) {
      console.error('Error loading bookmarks:', error);
      if (mountedRef.current) {
        setBookmarkedPlaces([]);
      }
    } finally {
      if (mountedRef.current) {
        setLoading(false);
      }
    }
  };

  const toggleBookmark = async (placeId: string): Promise<boolean> => {
    if (!mountedRef.current) return false;

    try {
      const isNowBookmarked = await BookmarkService.toggleBookmark(placeId);
      
      if (mountedRef.current) {
        if (isNowBookmarked) {
          setBookmarkedPlaces(prev => [...prev, placeId]);
        } else {
          setBookmarkedPlaces(prev => prev.filter(id => id !== placeId));
        }
      }
      
      return isNowBookmarked;
    } catch (error) {
      console.error('Error toggling bookmark:', error);
      return false;
    }
  };

  const isBookmarked = (placeId: string): boolean => {
    return bookmarkedPlaces.includes(placeId);
  };

  return {
    bookmarkedPlaces,
    loading,
    toggleBookmark,
    isBookmarked,
    refreshBookmarks: loadBookmarks,
  };
}