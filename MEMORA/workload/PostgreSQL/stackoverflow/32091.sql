
WITH RecursivePostVotes AS (
    SELECT 
        p.Id AS PostId,
        p.ViewCount,
        COALESCE(vt.Name, 'No Vote') AS VoteType,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY v.CreationDate DESC) AS VoteRank,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
), 
PostScoreHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT ph.UserId) AS EditCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY 
        ph.PostId, 
        ph.CreationDate
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, 
        u.DisplayName
),
PostAnalytics AS (
    SELECT 
        p.Title,
        p.Id,
        p.CreationDate,
        COALESCE(rv.VoteType, 'No Votes') AS LatestVote,
        ph.TotalScore,
        ph.EditCount,
        u.BadgeCount,
        DENSE_RANK() OVER (ORDER BY ph.TotalScore DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePostVotes rv ON p.Id = rv.PostId
    LEFT JOIN 
        PostScoreHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        UsersWithBadges u ON p.OwnerUserId = u.UserId
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
        AND (p.Score > 0 OR ph.EditCount > 5)
)

SELECT 
    pa.Title,
    pa.Id,
    pa.CreationDate,
    pa.LatestVote,
    pa.TotalScore,
    pa.EditCount,
    pa.BadgeCount,
    CASE 
        WHEN pa.BadgeCount = 0 THEN 'No Badges'
        ELSE 'Has Badges'
    END AS BadgeStatus
FROM 
    PostAnalytics pa
WHERE 
    pa.ScoreRank <= 10
ORDER BY 
    pa.TotalScore DESC, 
    pa.EditCount DESC;
