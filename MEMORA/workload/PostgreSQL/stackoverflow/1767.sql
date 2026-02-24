
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        AVG(p.Score) AS AvgPostScore,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(p.Score) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(Id) AS VoteCount
        FROM 
            Votes 
        WHERE 
            VoteTypeId IN (2, 3) 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),

TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalVotes, 
        AvgPostScore
    FROM 
        UserPostStats
    WHERE 
        UserRank <= 10
)

SELECT 
    t.DisplayName,
    t.TotalPosts,
    t.TotalVotes,
    t.AvgPostScore,
    p.Title,
    p.CreationDate,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT pt.Id) AS PostTags,
    (
        SELECT 
            STRING_AGG(DISTINCT tg.TagName, ', ') 
        FROM 
            Tags tg 
        WHERE 
            p.Tags LIKE CONCAT('%', tg.TagName, '%')
    ) AS TagsList
FROM 
    TopUsers t
JOIN 
    Posts p ON t.UserId = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    Posts pt ON pl.RelatedPostId = pt.Id
WHERE 
    p.ViewCount > 100
GROUP BY 
    t.DisplayName, t.TotalPosts, t.TotalVotes, t.AvgPostScore, p.Id, p.Title, p.CreationDate
HAVING 
    COUNT(c.Id) > 5
ORDER BY 
    t.TotalVotes DESC;
