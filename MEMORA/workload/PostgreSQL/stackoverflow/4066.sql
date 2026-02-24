WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
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
        PostCount,
        TotalBounty,
        UpVotesCount,
        DownVotesCount
    FROM 
        UserActivity
    WHERE 
        UserRank <= 10
),
PostSummary AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentsCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalBounty,
    p.Title,
    p.CreationDate,
    p.CommentsCount,
    p.CloseCount
FROM 
    TopUsers tu
JOIN 
    PostSummary p ON tu.UserId = p.Id
ORDER BY 
    tu.TotalBounty DESC,
    p.CommentsCount DESC
LIMIT 20;