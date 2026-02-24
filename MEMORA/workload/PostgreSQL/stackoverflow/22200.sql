
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank,
        COALESCE(p.AcceptedAnswerId, -1) AS AnswerStatus,
        COALESCE(ph.Comment, 'No Reason') AS CloseReason,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10  
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, ph.Comment, p.PostTypeId
), TopPosts AS (
    SELECT 
        *,
        CASE 
            WHEN AnswerStatus <> -1 THEN 'Answered'
            ELSE 'Unanswered'
        END AS AnsweredStatus
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10  
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.CloseReason,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.GoldBadges,
    tp.SilverBadges,
    tp.AnsweredStatus,
    CASE 
        WHEN tp.CloseReason IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN tp.GoldBadges > 0 THEN 'Gold Member'
        WHEN tp.SilverBadges > 0 THEN 'Silver Member'
        ELSE 'Regular User'
    END AS UserMembershipStatus
FROM 
    TopPosts tp
ORDER BY 
    CASE 
        WHEN tp.Score IS NULL THEN 0 ELSE 1 END DESC, 
    tp.Score DESC, 
    tp.ViewCount DESC;
