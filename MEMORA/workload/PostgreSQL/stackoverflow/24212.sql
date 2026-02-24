
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostDetails AS (
    SELECT
        r.PostId,
        r.Title,
        r.Score,
        r.ViewCount,
        CASE 
            WHEN r.AcceptedAnswerId IS NULL THEN 'No Accepted Answer'
            ELSE 'Accepted Answer Exists'
        END AS AcceptedAnswerStatus,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = r.PostId) AS CommentCount,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = r.PostId AND v.VoteTypeId = 2) AS UpVotes, 
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = r.PostId AND v.VoteTypeId = 3) AS DownVotes 
    FROM 
        RankedPosts r
    WHERE 
        r.RankByScore <= 5 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsMade,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 0 
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        pt.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
),
UnionResults AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Score,
        pd.ViewCount,
        pd.AcceptedAnswerStatus,
        pd.CommentCount,
        'Top Posts' AS Source
    FROM 
        PostDetails pd
    UNION ALL
    SELECT 
        NULL AS PostId, 
        NULL AS Title,
        NULL AS Score,
        NULL AS ViewCount,
        NULL AS AcceptedAnswerStatus,
        NULL AS CommentCount,
        'Closed Posts' AS Source
    FROM 
        ClosedPosts cp
)
SELECT 
    ur.*, 
    COALESCE(u.DisplayName, 'Anonymous') AS UserDisplayName,
    u.PostsMade,
    u.TotalUpVotes,
    u.TotalDownVotes
FROM 
    UnionResults ur
LEFT JOIN 
    UserActivity u ON ur.PostId = u.UserId
ORDER BY 
    ur.Source,
    ur.Score DESC;
