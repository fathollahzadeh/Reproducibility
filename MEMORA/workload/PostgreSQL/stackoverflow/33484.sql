
WITH UserPostActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        AVG(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - p.CreationDate))) / 3600 AS AvgHoursSincePost 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId = p.Id 
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        p.Title,
        ph.PostHistoryTypeId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    upa.UserId,
    upa.UserName,
    upa.PostCount,
    upa.QuestionCount,
    upa.AnswerCount,
    upa.TotalBounty,
    upa.AvgHoursSincePost,
    COALESCE(rp.Title, 'No Recent Activity') AS RecentPostTitle,
    COALESCE(rp.Comment, 'No Comments') AS LastActionComment,
    rp.CreationDate AS LastActionDate
FROM 
    UserPostActivity upa
LEFT JOIN 
    RecentPostHistory rp ON upa.UserId = rp.UserId AND rp.rn = 1
WHERE 
    upa.PostCount > 10
ORDER BY 
    upa.TotalBounty DESC, upa.QuestionCount DESC;
