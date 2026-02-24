
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        MAX(p.CreationDate) AS MostRecentActivity
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM PostHistory ph
    JOIN CloseReasonTypes crt ON ph.Comment = crt.Id::text
    WHERE ph.PostHistoryTypeId IN (10, 11)
    GROUP BY ph.PostId
),
PostAnalytics AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ur.DisplayName AS OwnerName,
        ur.Reputation AS OwnerReputation,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        COALESCE(clp.CloseReasons, 'No Reasons') AS CloseReasons,
        COALESCE(clp.FirstClosedDate::text, 'Open') AS PostStatus,
        RANK() OVER (PARTITION BY CASE WHEN clp.CloseReasons IS NOT NULL THEN 1 ELSE 0 END 
                     ORDER BY ps.UpVoteCount DESC) AS VoteRank
    FROM PostStats ps
    JOIN UserReputation ur ON ps.OwnerUserId = ur.UserId
    LEFT JOIN ClosedPosts clp ON ps.PostId = clp.PostId
)
SELECT 
    pa.Title,
    pa.OwnerName,
    pa.OwnerReputation,
    pa.UpVoteCount,
    pa.DownVoteCount,
    pa.CommentCount,
    pa.CloseReasons,
    pa.PostStatus,
    CASE WHEN pa.CloseReasons != 'No Reasons' THEN 'Closed' ELSE 'Active' END AS PostLifecycle,
    CASE WHEN pa.OwnerReputation = 0 THEN 'Newbie' ELSE 'Established' END AS UserType
FROM PostAnalytics pa
WHERE (pa.UpVoteCount + pa.CommentCount) > 10
ORDER BY pa.VoteRank, pa.OwnerReputation DESC, pa.UpVoteCount DESC
LIMIT 20;
