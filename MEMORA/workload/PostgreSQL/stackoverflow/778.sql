
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotesCount,  
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotesCount  
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')  
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.Rank,
        rp.UpVotesCount,
        rp.DownVotesCount,
        CASE 
            WHEN rp.Score >= 0 THEN 'Positive'
            WHEN rp.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10  
),
PostDetails AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Score,
        fp.CreationDate,
        fp.ScoreCategory,
        COALESCE(c.CommentCount, 0) AS Comments,
        COALESCE(b.BadgeCount, 0) AS UserBadges
    FROM 
        FilteredPosts fp
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON fp.PostId = c.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON fp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = b.UserId)  
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.CreationDate,
    pd.ScoreCategory,
    pd.Comments,
    pd.UserBadges
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC
LIMIT 50
OFFSET 0;
