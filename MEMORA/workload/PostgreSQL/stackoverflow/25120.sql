WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(v.UpVoteCount, 0) DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON p.OwnerUserId = b.UserId
    WHERE
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days' 
)
SELECT 
    r.PostId,
    r.Title,
    r.Body,
    r.CreationDate,
    r.UpVoteCount,
    r.DownVoteCount,
    r.CommentCount,
    r.BadgeCount,
    p.PostTypeId,
    CASE 
        WHEN r.Rank <= 10 THEN 'Top' 
        WHEN r.Rank <= 20 THEN 'Mid' 
        ELSE 'Low' 
    END AS RankingCategory
FROM 
    RankedPosts r
JOIN 
    Posts p ON r.PostId = p.Id
WHERE 
    p.PostTypeId IN (1, 2) 
ORDER BY 
    r.Rank;