WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
), RecentPosts AS (
    SELECT 
        rp.*,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.rn <= 10 
), ClosedReasonCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS CloseReasonCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10 
    GROUP BY 
        p.Id
), VotesSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(rc.CloseReasonCount, 0) AS CloseReasonCount,
    CASE WHEN vs.UpVotes IS NOT NULL AND vs.DownVotes IS NOT NULL 
         THEN (vs.UpVotes + vs.DownVotes)
         ELSE 0 END AS TotalVotes,
    CASE 
        WHEN rc.CloseReasonCount > 0 THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus,
    DATE_TRUNC('day', rp.CreationDate) AS CreationDateTruncated
FROM 
    RecentPosts rp
LEFT JOIN 
    VotesSummary vs ON rp.PostId = vs.PostId
LEFT JOIN 
    ClosedReasonCounts rc ON rp.PostId = rc.PostId
ORDER BY 
    rp.CreationDate DESC;