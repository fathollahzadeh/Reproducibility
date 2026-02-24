WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId, p.OwnerUserId, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Post Closed'
            WHEN ph.PostHistoryTypeId = 11 THEN 'Post Reopened'
            ELSE 'Other Reason'
        END AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.OwnerDisplayName,
        rp.CreationDate,
        COALESCE(cp.CloseReason, 'Not Closed') AS CloseStatus
    FROM 
        RecentPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.rn <= 5
)
SELECT 
    tp.Title,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.OwnerDisplayName,
    tp.CreationDate,
    CASE 
        WHEN tp.CloseStatus <> 'Not Closed' THEN 'Closed: ' || tp.CloseStatus 
        ELSE 'Open'
    END AS Status,
    CASE 
        WHEN (tp.UpVotes - tp.DownVotes) < 0 THEN 'Negative Feedback'
        ELSE 'Feedback OK'
    END AS FeedbackAssessment
FROM 
    TopPosts tp
ORDER BY 
    tp.UpVotes - tp.DownVotes DESC, 
    tp.CommentCount DESC;