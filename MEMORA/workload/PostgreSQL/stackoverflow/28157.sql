
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        u.DisplayName AS AuthorName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts AS p
    JOIN 
        Users AS u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments AS c ON p.Id = c.PostId
    LEFT JOIN 
        Votes AS v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Body
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Body,
        rp.AuthorName,
        rp.CommentCount,
        rp.UpVotes
    FROM 
        RankedPosts AS rp
    WHERE 
        rp.Rank = 1
),
MostDiscussedPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.AuthorName,
        fp.CommentCount,
        fp.UpVotes
    FROM 
        FilteredPosts AS fp
    WHERE 
        fp.CommentCount > 10 
    ORDER BY 
        fp.CommentCount DESC
    LIMIT 10
),
PostHistoryDetails AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS HistoryDate,
        pht.Name AS HistoryType,
        ph.Comment
    FROM 
        PostHistory AS ph
    JOIN 
        Posts AS p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes AS pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate BETWEEN (CAST('2024-10-01' AS DATE) - INTERVAL '30 days') AND CAST('2024-10-01' AS DATE)
)
SELECT 
    mdp.PostId,
    mdp.Title,
    mdp.AuthorName,
    mdp.CommentCount,
    mdp.UpVotes,
    (SELECT 
        STRING_AGG(HistoryType || ': ' || CAST(HistoryDate AS TEXT), '; ') 
     FROM 
        PostHistoryDetails 
     WHERE 
        PostId = mdp.PostId) AS HistoryDetails
FROM 
    MostDiscussedPosts AS mdp
ORDER BY 
    mdp.CommentCount DESC;
