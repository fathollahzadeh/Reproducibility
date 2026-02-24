
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalQuestions,
        TotalAnswers,
        UpVotes - DownVotes AS NetVotes
    FROM 
        UserStats
    ORDER BY 
        NetVotes DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        array_agg(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '>')) AS t(TagName) ON t.TagName IS NOT NULL
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score, pt.Name
)
SELECT 
    tu.DisplayName AS TopUser,
    pd.Title AS PostTitle,
    pd.CreationDate AS PostDate,
    pd.Score AS PostScore,
    pd.PostType AS TypeOfPost,
    pd.Tags AS AssociatedTags
FROM 
    TopUsers tu
JOIN 
    PostDetails pd ON tu.DisplayName = pd.OwnerDisplayName
ORDER BY 
    tu.NetVotes DESC, pd.Score DESC;
