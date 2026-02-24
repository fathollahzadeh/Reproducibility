WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        UserActivity
    WHERE 
        Rank <= 10
)

SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.CommentCount,
    tu.UpVoteCount,
    tu.DownVoteCount,
    COALESCE(pt.Name, 'N/A') AS PostType,
    COALESCE(tg.TagName, 'N/A') AS TagName
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Tags tg ON p.Tags LIKE '%' || tg.TagName || '%'
ORDER BY 
    tu.PostCount DESC, tu.CommentCount DESC;
