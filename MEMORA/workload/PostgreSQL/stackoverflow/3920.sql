
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
PostsWithHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(ph.EditCount, 0) AS TotalEdits,
        ph.LastEditDate
    FROM 
        Posts p 
    LEFT JOIN 
        PostHistories ph ON p.Id = ph.PostId
),
RankedPosts AS (
    SELECT 
        pwh.*,
        RANK() OVER (ORDER BY pwh.TotalEdits DESC, pwh.CreationDate ASC) AS EditRank
    FROM 
        PostsWithHistory pwh
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalBounty,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.TotalEdits,
    rp.LastEditDate,
    rp.EditRank
FROM 
    UserPostStats ups
JOIN 
    RankedPosts rp ON ups.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = rp.PostId)
WHERE 
    ups.UserRank <= 10 
    AND (rp.LastEditDate IS NULL OR rp.LastEditDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'))
ORDER BY 
    ups.PostCount DESC, 
    rp.EditRank;
