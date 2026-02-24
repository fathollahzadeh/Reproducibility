WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalViews,
        TotalBounty,
        QuestionCount,
        AnswerCount,
        LastPostDate,
        RANK() OVER (ORDER BY TotalViews DESC, TotalBounty DESC) AS ViewRank,
        RANK() OVER (ORDER BY QuestionCount DESC, AnswerCount DESC) AS ActivityRank
    FROM 
        UserActivity
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalViews,
        TotalBounty,
        QuestionCount,
        AnswerCount,
        LastPostDate,
        ViewRank,
        ActivityRank
    FROM 
        RankedUsers
    WHERE 
        ViewRank <= 10 OR ActivityRank <= 10
),
PostHistoryAggregates AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (2, 5) THEN 1 ELSE 0 END) AS BodyEdits,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS ClosureEdits
    FROM 
        PostHistory ph 
    GROUP BY 
        ph.UserId
)
SELECT 
    tu.DisplayName,
    tu.TotalViews,
    tu.TotalBounty,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.LastPostDate,
    COALESCE(pha.EditCount, 0) AS TotalEdits,
    COALESCE(pha.BodyEdits, 0) AS BodyEditCount,
    COALESCE(pha.ClosureEdits, 0) AS ClosureEditCount,
    CASE 
        WHEN COALESCE(pha.EditCount, 0) > 0 
        THEN ROUND(COALESCE(tu.TotalViews, 0) / NULLIF(pha.EditCount, 0), 2) 
        ELSE NULL 
    END AS ViewsPerEdit,
    CASE 
        WHEN tu.AnswerCount > 0 
        THEN ROUND(COALESCE(tu.TotalBounty, 0) / NULLIF(tu.AnswerCount, 0), 2) 
        ELSE NULL 
    END AS AverageBountyPerAnswer
FROM 
    TopUsers tu
LEFT JOIN 
    PostHistoryAggregates pha ON tu.UserId = pha.UserId
ORDER BY 
    tu.TotalViews DESC, tu.TotalBounty DESC;