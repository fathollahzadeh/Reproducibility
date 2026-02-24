
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.LastActivityDate >= CURRENT_DATE - INTERVAL '6 MONTH'
), 
PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        PostId
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.AnswerCount,
        rp.ViewCount,
        pvs.UpVotes,
        pvs.DownVotes,
        pvs.TotalVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteStats pvs ON rp.PostId = pvs.PostId
    WHERE 
        rp.Rank <= 5
)

SELECT 
    tp.*, 
    COALESCE(tp.UpVotes, 0) - COALESCE(tp.DownVotes, 0) AS NetVotes,
    CASE 
        WHEN tp.ViewCount > 1000 THEN 'High Traffic'
        WHEN tp.ViewCount BETWEEN 500 AND 1000 THEN 'Medium Traffic'
        ELSE 'Low Traffic'
    END AS TrafficCategory
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
WHERE 
    ph.CreationDate BETWEEN CURRENT_DATE - INTERVAL '1 YEAR' AND CURRENT_DATE
    AND ph.PostHistoryTypeId NOT IN (12, 10) 
ORDER BY 
    NetVotes DESC, 
    tp.CreationDate DESC;
