WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - u.CreationDate)) / 86400) AS DaysActive
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    GROUP BY 
        u.Id
),
RecentEdits AS (
    SELECT 
        p.Id AS PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24) 
    ORDER BY 
        ph.CreationDate DESC
    LIMIT 10
),
VoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 9) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    us.QuestionsAsked,
    us.AcceptedAnswers,
    us.DaysActive,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    vs.UpVotes,
    vs.DownVotes,
    re.UserDisplayName AS LastEditor,
    re.EditDate,
    re.Comment
FROM 
    Users u
LEFT JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    VoteSummary vs ON rp.PostId = vs.PostId
LEFT JOIN 
    RecentEdits re ON rp.PostId = re.PostId
WHERE 
    u.Reputation > 1000 
ORDER BY 
    us.QuestionsAsked DESC, 
    us.AcceptedAnswers DESC, 
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY
;