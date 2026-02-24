WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT CASE WHEN c.Id IS NOT NULL THEN c.Id END) AS CommentCount,
        COUNT(DISTINCT CASE WHEN a.Id IS NOT NULL THEN a.Id END) AS AnswerCount,
        MAX(v.CreationDate) AS LastVoteDate,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score
),
RankedPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        CreationDate,
        Score,
        CommentCount,
        AnswerCount,
        LastVoteDate,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        PostStats
)
SELECT 
    rp.Rank,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.AnswerCount,
    rp.LastVoteDate,
    rp.BadgeCount,
    u.DisplayName AS PostOwner,
    u.Reputation AS OwnerReputation
FROM 
    RankedPosts rp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;