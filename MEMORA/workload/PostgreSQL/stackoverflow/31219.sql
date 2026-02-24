WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Author,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON c.PostId = rp.PostId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        rp.rn = 1
),
FilteredPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Author,
        pd.Score,
        pd.ViewCount,
        pd.AnswerCount,
        pd.CommentCount,
        pd.BadgeCount,
        DENSE_RANK() OVER (ORDER BY pd.Score DESC) AS ScoreRank
    FROM 
        PostDetails pd
    WHERE 
        pd.Score > 5 AND (pd.CommentCount = 0 OR pd.BadgeCount > 1)
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Author,
    fp.Score,
    fp.ViewCount,
    fp.AnswerCount,
    fp.CommentCount,
    fp.BadgeCount,
    CASE 
        WHEN fp.ScoreRank <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    FilteredPosts fp
WHERE 
    EXISTS (
        SELECT 1
        FROM Votes v 
        WHERE v.PostId = fp.PostId 
          AND v.VoteTypeId IN (2, 3) 
          AND v.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    )
ORDER BY 
    fp.ScoreRank;