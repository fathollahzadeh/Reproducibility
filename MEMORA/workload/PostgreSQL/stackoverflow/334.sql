WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
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
        PostCount,
        TotalViews,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        UserActivity
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)

SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.TotalViews,
    tu.UpVotes,
    tu.DownVotes,
    tu.ViewRank,
    COALESCE(cp.CloseCount, 0) AS ClosePostCount,
    CASE 
        WHEN tu.UpVotes > tu.DownVotes THEN 'Positive Contributor' 
        WHEN tu.UpVotes < tu.DownVotes THEN 'Negative Contributor' 
        ELSE 'Neutral Contributor' 
    END AS ContributorType
FROM 
    TopUsers tu
LEFT JOIN 
    ClosedPosts cp ON tu.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = cp.PostId LIMIT 1)
WHERE 
    tu.ViewRank <= 10 
ORDER BY 
    tu.ViewRank;