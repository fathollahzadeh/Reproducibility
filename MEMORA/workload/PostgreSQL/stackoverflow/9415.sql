WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        COALESCE(MAX(p.CreationDate), '1900-01-01') AS LatestPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    LEFT JOIN 
        Comments c ON u.Id = c.UserId AND c.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    LEFT JOIN (
        SELECT 
            postId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            postId
    ) v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalVotes,
        TotalBadges,
        LatestPostDate,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC, TotalVotes DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    ru.DisplayName,
    ru.TotalPosts,
    ru.TotalComments,
    ru.TotalVotes,
    ru.TotalBadges,
    ru.LatestPostDate
FROM 
    RankedUsers ru
WHERE 
    ru.Rank <= 10
ORDER BY 
    ru.Rank;