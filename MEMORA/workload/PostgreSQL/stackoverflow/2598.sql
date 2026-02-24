WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation,
        Views, 
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBounty,
        UserRank,
        (PostCount * 1.0 / NULLIF(QuestionCount, 0)) AS QuestionRatio,
        (PostCount * 1.0 / NULLIF(AnswerCount, 0)) AS AnswerRatio
    FROM 
        UserStats
    WHERE 
        Reputation > 100
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.UserId AS ClosedByUserId,
        ph.CreationDate AS CloseDate,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalBounty,
    cp.Title AS ClosedPostTitle,
    cp.CloseDate,
    cp.CloseReason
FROM 
    TopUsers tu
LEFT JOIN ClosedPosts cp ON tu.UserId = cp.ClosedByUserId
ORDER BY 
    tu.UserRank, cp.CloseDate DESC
FETCH FIRST 10 ROWS ONLY;
