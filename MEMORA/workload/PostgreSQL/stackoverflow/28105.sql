
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, 
        u.DisplayName, u.Reputation
),
RankedPosts AS (
    SELECT 
        rp.*,
        RANK() OVER (ORDER BY rp.ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY rp.AnswerCount DESC) AS AnswerRank
    FROM 
        RecentPosts rp
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    rp.CommentCount,
    rp.AnswerCount,
    rp.ViewCount,
    rp.LastEditDate,
    CASE 
        WHEN rp.ViewRank <= 10 THEN 'Top Viewed'
        WHEN rp.AnswerRank <= 10 THEN 'Top Answered'
        ELSE 'Moderate'
    END AS PostStatus
FROM 
    RankedPosts rp
WHERE 
    rp.CommentCount > 0
    OR rp.AnswerCount > 0
ORDER BY 
    rp.ViewRank, rp.AnswerRank;
