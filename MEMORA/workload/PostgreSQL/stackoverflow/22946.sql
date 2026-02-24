WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
),
TopPosts AS (
    SELECT PostId, Title, Score, ViewCount
    FROM RankedPosts
    WHERE Rank <= 10
),
PostVoteCount AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),
PostWithBadges AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(b.Count, 0) AS BadgeCount
    FROM TopPosts p
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS Count
        FROM Badges
        GROUP BY UserId
    ) b ON b.UserId = (
        SELECT OwnerUserId FROM Posts WHERE Id = p.PostId
    )
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed' 
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened' 
            ELSE NULL END, ', ') AS HistoryTypes
    FROM PostHistory ph
    GROUP BY ph.PostId
),
FinalResults AS (
    SELECT 
        p.Title,
        p.Score,
        p.ViewCount,
        p.BadgeCount,
        ph.HistoryCount,
        COALESCE(ph.HistoryTypes, 'No History') AS HistoryInfo,
        CASE 
            WHEN p.Score >= 100 THEN 'Highly Rated'
            WHEN p.Score BETWEEN 50 AND 99 THEN 'Moderately Rated'
            ELSE 'Low Rated'
        END AS RatingCategory
    FROM PostWithBadges p
    LEFT JOIN PostHistoryStats ph ON p.PostId = ph.PostId
)
SELECT 
    Title,
    Score,
    ViewCount,
    BadgeCount,
    HistoryCount,
    HistoryInfo,
    RatingCategory
FROM FinalResults
WHERE BadgeCount > 0
ORDER BY Score DESC, ViewCount DESC;