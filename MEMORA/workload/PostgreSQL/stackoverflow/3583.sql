
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN vt.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(AVG(CASE WHEN p.Score <> 0 THEN p.Score ELSE NULL END), 0) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostLinksInfo AS (
    SELECT 
        pl.PostId,
        COUNT(*) AS RelatedPostCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)

SELECT 
    us.DisplayName,
    us.QuestionCount,
    us.UpVotes,
    us.DownVotes,
    us.AvgScore,
    COALESCE(rp.Title, 'No Questions') AS TopQuestion,
    COALESCE(rp.Score, 0) AS TopQuestionScore,
    COALESCE(pli.RelatedPostCount, 0) AS RelatedPostLinks
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    PostLinksInfo pli ON rp.PostId = pli.PostId
WHERE 
    us.QuestionCount > 0
ORDER BY 
    us.QuestionCount DESC, us.UpVotes DESC
LIMIT 100;
