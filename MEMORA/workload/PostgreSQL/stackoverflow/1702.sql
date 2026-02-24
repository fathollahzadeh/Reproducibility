WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS Ranking
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        PostCount,
        CommentCount
    FROM 
        UserActivity
    WHERE 
        Ranking <= 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COALESCE(pb.Body, 'No Body') AS PostBody,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            STRING_AGG(Text, ' ') AS Body 
         FROM 
            PostHistory 
         WHERE 
            PostHistoryTypeId = 2
         GROUP BY 
            PostId) pb ON p.Id = pb.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, pb.Body
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.UpVotes,
    tu.DownVotes,
    pd.Title AS PostTitle,
    pd.CreationDate AS PostDate,
    pd.PostBody,
    pd.TotalComments,
    pd.RelatedPostsCount
FROM 
    TopUsers tu
JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
JOIN 
    PostDetails pd ON p.Id = pd.PostId
ORDER BY 
    tu.UpVotes DESC, pd.CreationDate DESC;
