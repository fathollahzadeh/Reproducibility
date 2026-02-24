WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
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
        Questions,
        Answers,
        RANK() OVER (ORDER BY TotalVotes DESC) AS VoteRank
    FROM 
        UserActivity
),
RelatedPosts AS (
    SELECT 
        pl.PostId, 
        p.Title, 
        pl.RelatedPostId, 
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pl.RelatedPostId) AS CommentCount
    FROM 
        PostLinks pl 
    JOIN 
        Posts p ON pl.PostId = p.Id
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalVotes,
    tu.Questions,
    tu.Answers,
    rp.Title AS RelatedPostTitle,
    rp.CommentCount,
    CASE 
        WHEN tu.TotalVotes >= 100 THEN 'Gold'
        WHEN tu.TotalVotes >= 50 THEN 'Silver'
        WHEN tu.TotalVotes >= 10 THEN 'Bronze'
        ELSE 'No Badge' 
    END AS Badge
FROM 
    TopUsers tu
LEFT JOIN 
    RelatedPosts rp ON tu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.RelatedPostId)
WHERE 
    tu.VoteRank <= 10
ORDER BY 
    tu.TotalVotes DESC
