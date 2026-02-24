
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
        AND p.PostTypeId = 1 
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
), FilteredPosts AS (
    SELECT * 
    FROM RankedPosts 
    WHERE Rank <= 5
), PostDetails AS (
    SELECT 
        f.PostId,
        f.Title,
        f.OwnerName,
        f.CommentCount,
        f.UpVotes,
        f.DownVotes,
        COALESCE(NULLIF(b.Date, '1970-01-01'), NULL) AS BadgeAwardDate,
        (SELECT COUNT(*) 
         FROM PostHistory ph 
         WHERE ph.PostId = f.PostId 
         AND ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount
    FROM 
        FilteredPosts f
    LEFT JOIN 
        Badges b ON f.PostId = b.UserId
)
SELECT 
    d.PostId,
    d.Title,
    d.OwnerName,
    d.CommentCount,
    d.UpVotes,
    d.DownVotes,
    d.BadgeAwardDate,
    d.CloseReopenCount,
    CASE 
        WHEN d.UpVotes > d.DownVotes THEN 'Positive'
        WHEN d.UpVotes < d.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    PostDetails d
ORDER BY 
    d.UpVotes DESC, 
    d.CommentCount DESC
LIMIT 10;
