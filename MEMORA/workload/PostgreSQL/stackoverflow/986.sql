
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosters AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBounty,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM 
        UserPostStats
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        p.Title,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= DATE('2024-10-01') - INTERVAL '30 days'
)

SELECT 
    tp.DisplayName,
    tp.PostCount,
    tp.QuestionCount,
    tp.AnswerCount,
    tp.TotalBounty,
    COUNT(DISTINCT rph.PostId) AS RecentPostCount,
    AVG(CASE WHEN rph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS AvgClosedReopened 
FROM 
    TopPosters tp
LEFT JOIN 
    RecentPostHistory rph ON tp.UserId = rph.UserId AND rph.rn = 1
GROUP BY 
    tp.UserId, tp.DisplayName, tp.PostCount, tp.QuestionCount, tp.AnswerCount, tp.TotalBounty
HAVING 
    tp.PostCount > 10
ORDER BY 
    tp.PostCount DESC, tp.DisplayName;
