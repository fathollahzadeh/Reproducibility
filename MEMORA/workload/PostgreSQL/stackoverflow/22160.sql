
WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentEditRank
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (SELECT COUNT(*) FROM PostHistory WHERE PostId = p.Id AND PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
        (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = p.Id) AS RelatedPostsCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > '2024-10-01 12:34:56'::timestamp - INTERVAL '2 years'
    GROUP BY 
        p.Id, p.Title
),
FinalReport AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.CloseReopenCount,
        ps.RelatedPostsCount,
        COALESCE(rph.UserId, -1) AS LastEditorId,
        COALESCE(rph.CreationDate, '1900-01-01 00:00:00') AS LastEditDate,
        rph.Comment AS LastEditComment
    FROM 
        PostStatistics ps
    LEFT JOIN 
        RecursivePostHistory rph ON ps.PostId = rph.PostId AND rph.RecentEditRank = 1
)
SELECT 
    PostId,
    Title,
    CommentCount,
    UpVotes,
    DownVotes,
    CloseReopenCount,
    RelatedPostsCount,
    CASE 
        WHEN LastEditorId IS NULL THEN 'No edits yet'
        WHEN LastEditComment IS NULL THEN 'Edited with no comments'
        ELSE LastEditComment 
    END AS LastEditCommentDescription,
    CASE 
        WHEN LastEditDate < '2024-10-01 12:34:56'::timestamp - INTERVAL '6 months' THEN 'Stale post'
        ELSE 'Recently active'
    END AS PostActivityStatus
FROM 
    FinalReport
WHERE 
    (UpVotes - DownVotes) > 0
ORDER BY 
    UpVotes DESC, CommentCount DESC
LIMIT 10;
