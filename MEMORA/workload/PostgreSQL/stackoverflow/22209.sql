
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(DISTINCT ph.UserId) AS CloseVoteCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    up.DisplayName AS UserDisplayName,
    COUNT(DISTINCT rp.PostId) AS QuestionsCount,
    SUM(rp.ViewCount) AS TotalViews,
    SUM(rp.Score) AS TotalScore,
    COALESCE(cph.CloseVoteCount, 0) AS CloseVotes,
    us.BadgeCount,
    us.UpVoteCount,
    us.DownVoteCount,
    STRING_AGG(DISTINCT CASE WHEN rp.PostRank <= 5 THEN rp.Title END, '; ') AS TopQuestions
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    UserStats us ON up.Id = us.UserId
LEFT JOIN 
    ClosedPostHistory cph ON rp.PostId = cph.PostId
WHERE 
    (us.UpVoteCount IS NOT NULL AND us.UpVoteCount > 0) OR
    (us.BadgeCount IS NULL OR us.BadgeCount < 5)
GROUP BY 
    up.DisplayName, us.BadgeCount, us.UpVoteCount, us.DownVoteCount, cph.CloseVoteCount
HAVING 
    COUNT(DISTINCT rp.PostId) > 2
ORDER BY 
    TotalViews DESC, TotalScore DESC
LIMIT 10;
