
WITH UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        v.UserId
),
HighReputationUsers AS (
    SELECT 
        u.Id,
        u.Reputation,
        u.DisplayName,
        COALESCE(u.Views, 0) AS Views,
        COALESCE(b.Badges, 0) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS Badges
        FROM 
            Badges
        GROUP BY 
            UserId 
    ) b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate ASC) AS PopularityRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
    HAVING 
        COUNT(DISTINCT c.Id) > 0 OR COUNT(DISTINCT a.Id) > 0
),
VotesSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    pp.TotalUpvotes,
    pp.TotalDownvotes,
    u.Reputation,
    u.Views,
    u.BadgesCount,
    p.PopularityRank
FROM 
    HighReputationUsers u
INNER JOIN 
    VotesSummary pp ON u.Id = pp.PostId
INNER JOIN 
    PopularPosts p ON p.Id = pp.PostId
WHERE 
    pp.TotalUpvotes > pp.TotalDownvotes
    AND p.PopularityRank <= 10
ORDER BY 
    u.Reputation DESC, pp.TotalUpvotes DESC;
