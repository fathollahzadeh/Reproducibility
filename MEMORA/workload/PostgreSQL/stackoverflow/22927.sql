WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVoteCount,
        (SELECT COUNT(*) FROM Posts p2 WHERE p2.ParentId = p.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.ViewCount, 
        rp.CommentCount, 
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.AnswerCount,
        CASE 
            WHEN rp.UpVoteCount > rp.DownVoteCount THEN 'Positive' 
            WHEN rp.UpVoteCount < rp.DownVoteCount THEN 'Negative'
            ELSE 'Neutral' 
        END AS VoteSentiment
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByViews <= 5
),
PostHonestly AS (
    SELECT 
        fp.PostId, 
        fp.Title, 
        fp.ViewCount, 
        fp.CommentCount, 
        fp.UpVoteCount,
        fp.DownVoteCount,
        fp.AnswerCount,
        fp.VoteSentiment,
        COALESCE(b.Name, 'No Badge') AS UserBadge
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
),
FinalResult AS (
    SELECT 
        ph.PostId, 
        ph.Title, 
        ph.ViewCount, 
        ph.CommentCount,
        ph.UpVoteCount,
        ph.DownVoteCount,
        ph.AnswerCount,
        ph.VoteSentiment,
        ph.UserBadge,
        (SELECT COUNT(*) FROM PostHistory phis WHERE phis.PostId = ph.PostId AND phis.PostHistoryTypeId IN (10, 11)) AS CloseChangesCount
    FROM 
        PostHonestly ph
)
SELECT 
    fr.*, 
    CASE 
        WHEN fr.ViewCount IS NULL THEN 'Views Not Recorded' 
        ELSE 'Views Recorded' 
    END AS ViewState,
    CASE 
        WHEN fr.CloseChangesCount > 0 THEN 'Closed' 
        ELSE 'Open' 
    END AS PostState
FROM 
    FinalResult fr
ORDER BY 
    fr.ViewCount DESC, fr.AnswerCount DESC;