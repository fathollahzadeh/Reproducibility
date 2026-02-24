WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName, u.Reputation
),
FilteredPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        CreationDate, 
        ViewCount, 
        OwnerDisplayName, 
        OwnerReputation,
        CommentCount, 
        AnswerCount,
        RANK() OVER (ORDER BY ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY AnswerCount DESC) AS AnswerRank
    FROM 
        RankedPosts
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.ViewCount,
    fp.CommentCount,
    fp.AnswerCount,
    fp.OwnerDisplayName,
    fp.OwnerReputation,
    CASE 
        WHEN fp.ViewRank <= 10 THEN 'Top Viewed'
        WHEN fp.AnswerRank <= 10 THEN 'Top Answered'
        ELSE 'Other'
    END AS PostCategory
FROM 
    FilteredPosts fp
WHERE 
    fp.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    AND (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fp.PostId AND v.VoteTypeId = 2) >= 5
ORDER BY 
    fp.ViewCount DESC, fp.AnswerCount DESC;