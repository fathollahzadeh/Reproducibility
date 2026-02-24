WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT CASE WHEN c.Id IS NOT NULL THEN c.Id END) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.Id IS NOT NULL THEN v.Id END) AS VoteCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AverageUpVotes,
        AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS AverageDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName
),
Ranking AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        VoteCount,
        AverageUpVotes,
        AverageDownVotes,
        RANK() OVER (ORDER BY VoteCount DESC, CommentCount DESC) AS PostRank
    FROM 
        PostStats
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.OwnerDisplayName,
    r.CommentCount,
    r.VoteCount,
    r.AverageUpVotes,
    r.AverageDownVotes,
    r.PostRank,
    pt.Name AS PostType,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Ranking r
JOIN 
    PostTypes pt ON r.PostId = r.PostId  
LEFT JOIN 
    Badges b ON r.PostId = b.UserId
GROUP BY 
    r.PostId, r.Title, r.CreationDate, r.OwnerDisplayName, r.CommentCount, r.VoteCount, r.AverageUpVotes, r.AverageDownVotes, r.PostRank, pt.Name
ORDER BY 
    r.PostRank;