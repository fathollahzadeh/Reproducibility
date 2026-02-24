WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserPostStats
),
RecentActivities AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        p.Title,
        u.DisplayName AS EditorDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
)
SELECT 
    tu.DisplayName AS TopUserDisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalScore,
    ra.Title AS RecentPostTitle,
    ra.CreationDate AS RecentActivityDate,
    ra.Comment AS ActivityComment,
    ra.EditorDisplayName,
    ra.PostHistoryTypeId,
    COUNT(v.Id) AS VoteCount
FROM 
    TopUsers tu
LEFT JOIN 
    RecentActivities ra ON tu.UserId = ra.UserId AND ra.RecentRank = 1
LEFT JOIN 
    Votes v ON ra.PostId = v.PostId AND v.UserId = tu.UserId
WHERE 
    tu.Rank <= 10 
GROUP BY 
    tu.DisplayName, tu.PostCount, tu.QuestionCount, tu.AnswerCount, tu.TotalScore, 
    ra.Title, ra.CreationDate, ra.Comment, ra.EditorDisplayName, ra.PostHistoryTypeId
ORDER BY 
    tu.TotalScore DESC, ra.CreationDate DESC;