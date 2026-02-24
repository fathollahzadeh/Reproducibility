WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.LastActivityDate DESC) AS ActivityRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.LastActivityDate
),
VoteStatistics AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        CASE 
            WHEN cps.CloseCount IS NULL THEN 'Open'
            ELSE 'Closed'
        END AS PostStatus,
        vs.UpVotes,
        vs.DownVotes,
        (COALESCE(vs.UpVotes, 0) - COALESCE(vs.DownVotes, 0)) AS NetVotes,
        rp.ActivityRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        VoteStatistics vs ON rp.PostId = vs.PostId
    LEFT JOIN 
        ClosedPosts cps ON rp.PostId = cps.PostId
    WHERE 
        rp.ActivityRank <= 5
)
SELECT 
    PostId,
    Title,
    CommentCount,
    PostStatus,
    UpVotes,
    DownVotes,
    NetVotes
FROM 
    FinalResults
WHERE 
    (NetVotes > 0 AND PostStatus = 'Open')
    OR 
    (PostStatus = 'Closed' AND CommentCount > 5)
ORDER BY 
    NetVotes DESC, CommentCount DESC;