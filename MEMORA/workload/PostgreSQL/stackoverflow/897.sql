
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ue.UserId,
        ue.TotalBounties,
        ue.TotalPosts,
        ue.TotalComments,
        ue.PostRank
    FROM 
        UserEngagement ue
    WHERE 
        ue.PostRank <= 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
FinalResults AS (
    SELECT 
        tu.UserId,
        tu.TotalBounties,
        tu.TotalPosts,
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        ROW_NUMBER() OVER (PARTITION BY tu.UserId ORDER BY pd.Score DESC) AS PostRank
    FROM 
        TopUsers tu
    JOIN 
        PostDetails pd ON tu.TotalPosts > 0
)
SELECT 
    u.DisplayName,
    fr.TotalBounties,
    fr.TotalPosts,
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.CommentCount,
    fr.UpVotes,
    fr.DownVotes
FROM 
    FinalResults fr
JOIN 
    Users u ON fr.UserId = u.Id
WHERE 
    fr.PostRank <= 5
ORDER BY 
    fr.TotalBounties DESC, fr.CommentCount DESC;
