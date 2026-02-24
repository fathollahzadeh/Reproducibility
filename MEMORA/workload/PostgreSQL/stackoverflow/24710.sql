
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        SUM(p.Score) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY SUM(p.Score) DESC) AS PostRank
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.UserId, 
        COUNT(DISTINCT ph.PostId) AS ClosedCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 12) 
    GROUP BY 
        ph.UserId
),
FinalStats AS (
    SELECT 
        ur.UserId, 
        ur.DisplayName, 
        ur.Reputation,
        us.TotalPosts,
        us.Questions,
        us.Answers,
        us.TotalScore,
        us.AvgViews,
        COALESCE(cp.ClosedCount, 0) AS ClosedPosts,
        ur.ReputationRank,
        CASE 
            WHEN ur.Reputation >= 1000 THEN 'High' 
            WHEN ur.Reputation BETWEEN 500 AND 999 THEN 'Medium' 
            ELSE 'Low' 
        END AS ReputationCategory
    FROM 
        UserReputation ur
    LEFT JOIN 
        PostStats us ON ur.UserId = us.OwnerUserId
    LEFT JOIN 
        ClosedPosts cp ON ur.UserId = cp.UserId
)
SELECT 
    fs.DisplayName,
    CASE
        WHEN fs.ClosedPosts < 5 THEN 'Newbie'
        WHEN fs.ClosedPosts BETWEEN 5 AND 10 THEN 'Regular'
        ELSE 'Veteran'
    END AS ClosureExperience,
    fs.TotalPosts,
    fs.Questions,
    fs.Answers,
    fs.TotalScore,
    fs.AvgViews,
    fs.ClosedPosts,
    fs.ReputationCategory
FROM 
    FinalStats fs
WHERE 
    fs.Reputation > 100
ORDER BY 
    fs.ReputationRank, fs.TotalScore DESC
OFFSET 10 ROWS
FETCH NEXT 10 ROWS ONLY;
