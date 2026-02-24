WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikiCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
VotesSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.OwnerUserId
),
PostHistorySummary AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS TotalEdits,
        SUM(CASE WHEN pht.Name LIKE 'Edit%' THEN 1 ELSE 0 END) AS EditCount,
        SUM(CASE WHEN pht.Name LIKE 'Rollback%' THEN 1 ELSE 0 END) AS RollbackCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.UserId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalPosts,
    up.QuestionCount,
    up.AnswerCount,
    up.TagWikiCount,
    up.LastPostDate,
    vs.TotalVotes,
    vs.UpVotes,
    vs.DownVotes,
    phs.TotalEdits,
    phs.EditCount,
    phs.RollbackCount
FROM 
    UserPosts up
LEFT JOIN 
    VotesSummary vs ON up.UserId = vs.OwnerUserId
LEFT JOIN 
    PostHistorySummary phs ON up.UserId = phs.UserId
ORDER BY 
    up.TotalPosts DESC, up.LastPostDate DESC
LIMIT 100;
