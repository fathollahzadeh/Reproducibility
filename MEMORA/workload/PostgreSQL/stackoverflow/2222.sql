
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
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    WHERE 
        u.CreationDate >= '2023-01-01' 
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
        RANK() OVER (ORDER BY TotalViews DESC) AS RankByViews
    FROM 
        UserActivity
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalViews,
    tu.UpVotes,
    tu.DownVotes,
    CASE 
        WHEN tu.DownVotes > 0 THEN 'Needs Improvement'
        WHEN tu.UpVotes > tu.DownVotes THEN 'Positive Impact'
        ELSE 'Neutral Contribution'
    END AS ContributionStatus
FROM 
    TopUsers tu
WHERE 
    tu.RankByViews <= 10
UNION ALL
SELECT 
    'Average' AS DisplayName,
    AVG(PostCount) AS PostCount,
    AVG(TotalViews) AS TotalViews,
    AVG(UpVotes) AS UpVotes,
    AVG(DownVotes) AS DownVotes,
    CASE 
        WHEN AVG(DownVotes) > 0 THEN 'Needs Improvement'
        WHEN AVG(UpVotes) > AVG(DownVotes) THEN 'Positive Impact'
        ELSE 'Neutral Contribution'
    END AS ContributionStatus
FROM 
    TopUsers
HAVING 
    COUNT(UserId) > 0;
