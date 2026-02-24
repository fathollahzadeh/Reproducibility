
WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId, 
        ph.PostHistoryTypeId, 
        ph.CreationDate, 
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS RevisionOrder
    FROM 
        PostHistory ph
),
FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.CreationDate AS PostCreationDate,
        p.LastActivityDate, 
        p.Score,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.Score, u.DisplayName
),
PostsWithLinkInfo AS (
    SELECT 
        ll.PostId,
        ll.LinkTypeId,
        COUNT(ll.RelatedPostId) AS RelatedPosts
    FROM 
        PostLinks ll
    JOIN 
        FilteredPosts fp ON ll.PostId = fp.PostId
    GROUP BY 
        ll.PostId, ll.LinkTypeId
),
MaxVotes AS (
    SELECT 
        PostId, 
        MAX(UpVotes - DownVotes) AS MaxVoteDiff
    FROM 
        FilteredPosts
    GROUP BY 
        PostId
),
FinalResults AS (
    SELECT 
        fp.PostId,
        fp.Title, 
        fp.PostCreationDate,
        fp.LastActivityDate,
        fp.Score, 
        fp.CommentCount,
        fp.UpVotes,
        fp.DownVotes,
        mh.MaxVoteDiff,
        CASE 
            WHEN fp.Score >= 100 THEN 'High Score'
            WHEN fp.Score BETWEEN 50 AND 99 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory,
        STRING_AGG(DISTINCT lt.Name, ', ') AS LinkTypes
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        PostsWithLinkInfo pli ON fp.PostId = pli.PostId
    LEFT JOIN 
        LinkTypes lt ON pli.LinkTypeId = lt.Id
    LEFT JOIN 
        MaxVotes mh ON fp.PostId = mh.PostId
    GROUP BY 
        fp.PostId, fp.Title, fp.PostCreationDate, fp.LastActivityDate, 
        fp.Score, fp.CommentCount, fp.UpVotes, fp.DownVotes, mh.MaxVoteDiff
)
SELECT 
    fr.*,
    CASE 
        WHEN mh.MaxVoteDiff IS NULL THEN 'No Votes'
        WHEN mh.MaxVoteDiff < 0 THEN 'Negative Impact'
        WHEN mh.MaxVoteDiff > 0 THEN 'Positive Impact'
    END AS VoteImpact,
    CASE 
        WHEN EXISTS (SELECT 1 FROM RecursivePostHistory r WHERE r.PostId = fr.PostId AND r.PostHistoryTypeId = 10) THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    FinalResults fr
LEFT JOIN 
    MaxVotes mh ON fr.PostId = mh.PostId
ORDER BY 
    fr.Score DESC, 
    fr.CommentCount DESC
LIMIT 50;
