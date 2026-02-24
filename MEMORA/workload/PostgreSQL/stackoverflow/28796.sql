
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerName,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>.<')) AS TagName
        ) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1 AND  
        p.Score > 0 AND       
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, p.Score, u.DisplayName
),
PostEngagement AS (
    SELECT 
        rp.PostId,
        rp.OwnerName,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.VoteTypeId IN (2, 3)  
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    GROUP BY 
        rp.PostId, rp.OwnerName, rp.Title, rp.CreationDate, rp.ViewCount, rp.AnswerCount, rp.Score
),
FinalResults AS (
    SELECT 
        pe.*,
        CASE 
            WHEN HighestBadgeClass = 1 THEN 'Gold'
            WHEN HighestBadgeClass = 2 THEN 'Silver'
            WHEN HighestBadgeClass = 3 THEN 'Bronze'
            ELSE 'None'
        END AS BadgeStatus,
        CASE 
            WHEN AnswerCount > 5 THEN 'Highly Engaging'
            WHEN ViewCount > 100 THEN 'Popular'
            ELSE 'Average Engagement'
        END AS EngagementLevel
    FROM 
        PostEngagement pe
)
SELECT 
    PostId,
    OwnerName,
    Title,
    CreationDate,
    ViewCount,
    AnswerCount,
    Score,
    CommentCount,
    VoteCount,
    BadgeStatus,
    EngagementLevel
FROM 
    FinalResults
ORDER BY 
    Score DESC, ViewCount DESC, CreationDate DESC
FETCH FIRST 50 ROWS ONLY;
