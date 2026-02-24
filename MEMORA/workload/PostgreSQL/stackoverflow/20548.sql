WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 4 THEN 1 ELSE 0 END), 0) AS TotalTagWikis,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
),
BountyStats AS (
    SELECT
        v.UserId,
        COUNT(v.Id) AS TotalBountiesGiven,
        SUM(v.BountyAmount) AS TotalBountyAmount
    FROM
        Votes v
    WHERE
        v.VoteTypeId = 8  
    GROUP BY
        v.UserId
),
CombinedStats AS (
    SELECT
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalTagWikis,
        ups.AvgViews,
        COALESCE(bs.TotalBountiesGiven, 0) AS TotalBountiesGiven,
        COALESCE(bs.TotalBountyAmount, 0) AS TotalBountyAmount
    FROM
        UserPostStats ups
    LEFT JOIN
        BountyStats bs ON ups.UserId = bs.UserId
),
RankedUsers AS (
    SELECT
        *,
        RANK() OVER (ORDER BY TotalPosts DESC, AvgViews DESC) AS UserRank
    FROM
        CombinedStats
)
SELECT
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalTagWikis,
    AvgViews,
    TotalBountiesGiven,
    TotalBountyAmount,
    CASE
        WHEN TotalBountyAmount > 100 THEN 'High Bounty Giver'
        WHEN TotalBountyAmount BETWEEN 50 AND 100 THEN 'Moderate Bounty Giver'
        ELSE 'Low Bounty Giver'
    END AS BountyCategory,
    UserRank
FROM
    RankedUsers
WHERE
    UserRank <= 10
ORDER BY
    UserRank;