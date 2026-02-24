
WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        ph.Text,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN vt.Id = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Id = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
PostTagSummary AS (
    SELECT 
        p.Id AS PostId,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsAssociated,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '><')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName AS UserDisplayName,
    pst.PostId,
    pst.TagsAssociated,
    pst.TotalUpVotes,
    pst.TotalDownVotes,
    COALESCE(uVS.UpVotes, 0) AS UserUpVotes,
    COALESCE(uVS.DownVotes, 0) AS UserDownVotes,
    ph.Comment,
    ph.CreationDate AS HistoryCreatedDate,
    ph.PostHistoryTypeId,
    ph.Text AS HistoryText,
    (
        SELECT 
            COUNT(*) 
        FROM 
            PostHistory pH 
        WHERE 
            pH.PostId = pst.PostId 
            AND pH.PostHistoryTypeId IN (10, 11) 
            AND pH.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '30 days'
    ) AS RecentCloseOrReopenCount,
    RANK() OVER (PARTITION BY pst.PostId ORDER BY COALESCE(uVS.UpVotes, 0) DESC) AS RankByUpVotes
FROM 
    PostTagSummary pst
LEFT JOIN 
    Users u ON u.Id = pst.PostId  
LEFT JOIN 
    UserVoteStats uVS ON u.Id = uVS.UserId
LEFT JOIN 
    RecursivePostHistory ph ON pst.PostId = ph.PostId
WHERE 
    (EXTRACT(HOUR FROM ph.CreationDate) % 2 = 0 OR ph.Comment IS NOT NULL)
    AND (pst.TotalUpVotes - pst.TotalDownVotes > 0 OR pst.CommentCount > 5)
ORDER BY 
    pst.TotalUpVotes DESC, 
    pst.TotalDownVotes ASC, 
    ph.CreationDate DESC
LIMIT 100;
